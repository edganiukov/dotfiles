call plug#begin('~/.config/nvim/plugged')

" Plugins
Plug 'joshdick/onedark.vim'
Plug 'itchyny/lightline.vim'
Plug 'jlanzarotta/bufexplorer'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/syntastic'
Plug 'junegunn/fzf.vim'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'SirVer/ultisnips'

Plug 'fatih/vim-go', { 'for': 'go' }
Plug 'klen/python-mode', { 'for': 'py' }
Plug 'lervag/vimtex', { 'for': 'tex' }
Plug 'tpope/vim-markdown', { 'for': 'md' }

Plug 'Shougo/deoplete.nvim'
Plug 'zchee/deoplete-go', { 'do': 'make'}
Plug 'zchee/deoplete-jedi'

call plug#end()

let $NVIM_TUI_ENABLE_CURSOR_SHAPE=1
set clipboard^=unnamed
set clipboard^=unnamedplus

syntax on
colorscheme onedark
highlight LineNr term=bold cterm=bold ctermfg=DarkGrey ctermbg=NONE

if has("gui_running")
    set guifont=Consolas:h14
    set background=dark
    set go-=L
    set go-=r
    set go-=m
    set go-=T
endif

set autoread
set incsearch
set hlsearch
set backspace=indent,eol,start

set noerrorbells
set novisualbell
set tm=500
set vb t_vb=

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

set mouse=a
set scrolloff=4
set backspace=2
set gcr=a:blinkon0
set pumheight=15
set colorcolumn=81

set cursorline
set pastetoggle=<F2>
set nopaste

set completeopt=menu,menuone,noinsert,noselect

" mappings
let mapleader = "\<Space>"

nnoremap <Leader>w :w<CR>
nnoremap <leader><space> :nohlsearch<CR>
nnoremap <leader>a :cclose<CR>
nnoremap <F10> :set list!<CR>
nnoremap <C-p> :FZF<CR>
nnoremap Y y$
inoremap <F10> <Esc>:set list!<CR>a

" buffers switch
map <leader>n :bn!<CR>
map <leader>m :bp!<CR>

" quickfix jump
map <C-n> :cn<CR>
map <C-m> :cp<CR>

imap hh <Esc>

" window navigation
nmap <C-h> <C-w>h
nmap <C-j> <C-w>j
nmap <C-k> <C-w>k
nmap <C-l> <C-w>l

" disable arrows
inoremap <Up> <NOP>
inoremap <Down> <NOP>
inoremap <Left> <NOP>
inoremap <Right> <NOP>
noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>

highlight ExtraWhitespace ctermbg=DarkGrey guibg=DarkGrey
match ExtraWhitespace /\s\+$/
nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

" Plugins

" syntastic
let g:syntastic_aggregate_errors = 1
let g:syntastic_enable_signs=1
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 0
let g:syntastic_go_checkers = ['golint', 'govet', "go"]

" completion
let g:deoplete#enable_at_startup = 1
let g:deoplete#ignore_sources = {}
let g:deoplete#ignore_sources._ = ['buffer', 'member', 'tag', 'file', 'neosnippet']
let g:deoplete#sources#go#sort_class = ['func', 'type', 'var', 'const']
let g:deoplete#sources#go#align_class = 1

" Use partial fuzzy matches like YouCompleteMe
call deoplete#custom#set('_', 'matchers', ['matcher_fuzzy'])
call deoplete#custom#set('_', 'converters', ['converter_remove_paren'])
call deoplete#custom#set('_', 'disabled_syntaxes', ['Comment', 'String'])

" fzf
set rtp+=/usr/local/opt/fzf
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

" lightline
let g:bufferline_echo = 0
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
let g:go_decls_included = "type,func"

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
