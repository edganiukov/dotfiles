set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" Plugins
Plugin 'chriskempson/base16-vim'
Plugin 'Shougo/echodoc.vim'
Plugin 'Shougo/neocomplete.vim'
Plugin 'scrooloose/nerdcommenter'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/syntastic'
Plugin 'majutsushi/tagbar'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'airblade/vim-gitgutter'
Plugin 'tpope/vim-fugitive'
Plugin 'fatih/vim-go'
Plugin 'Blackrush/vim-gocode'
Plugin 'garyburd/go-explorer'
Plugin 'rust-lang/rust.vim'
Plugin 'racer-rust/vim-racer'
call vundle#end()
filetype plugin indent on

colorscheme base16-eighties
set guifont=Consolas:h13
set background=dark
if has("gui_running")
	set fullscreen
endif

syntax on
highlight LineNr term=bold cterm=NONE ctermfg=DarkGrey ctermbg=NONE gui=NONE guifg=DarkGrey guibg=NONE

set noerrorbells
set novisualbell
set t_vb=
set tm=500

set encoding=utf-8
set autoindent
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set wrap
set viminfo='20,<1000,s10,h
set history=1000
set number

set showcmd
set wildmenu
set lazyredraw
set showmatch
set mouse=a
set pastetoggle=<F9>
set ignorecase
set smartcase
set incsearch
set hlsearch

nnoremap <leader><space> :nohlsearch<CR>
nnoremap <F10> :set invnumber<CR>
noremap <F11> :set list!<CR>
inoremap <F11> <Esc>:set list!<CR>a
map <C-c><C-Right> :bn!<CR>
map <C-c><C-Left> :bp!<CR>


set laststatus=2
set noshowmode
let g:bufferline_echo = 0

highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/

set nobackup
set nowb
set noswapfile

" Plugins config
" NERDTree
let NERDTreeDirArrows=1
let NERDTreeMinimalUI=1
let NERDTreeIgnore=['bin/*', 'build/*', 'pkg/*', '\.test$']
let g:NERDTreeWinSize=40

map <leader>f :NERDTreeFind<cr>
map <C-n> :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" syntastic
let g:syntastic_aggregate_errors = 1
let g:syntastic_enable_signs=1
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 1
let g:syntastic_go_checkers = ['golint', 'govet']

" neocomplete
set completeopt-=preview
let g:acp_enableAtStartup = 0
let g:neocomplete#enable_at_startup = 1
let g:echodoc_enable_at_startup = 1
let g:neocomplete#sources#syntax#min_keyword_length = 1
let g:neocomplete#enable_auto_close_preview = 1

inoremap <expr><TAB>  pumvisible() ? "\<C-n>" :
	\ <SID>check_back_space() ? "\<TAB>" :
    \ neocomplete#start_manual_complete()
function! s:check_back_space() "{{{
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~ '\s'
endfunction"}}}

if !exists('g:neocomplete#sources')
  let g:neocomplete#sources = {}
endif
let g:neocomplete#sources._ = []
let g:neocomplete#sources.go = ['omni']
let g:neocomplete#sources.rust = ['omni']

if !exists('g:neocomplete#keyword_patterns')
    let g:neocomplete#keyword_patterns = {}
endif
let g:neocomplete#keyword_patterns['default'] = '[^.[:digit:] *\t]\.\w*'

" gocode config
let g:go_disable_autoinstall = 0
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_interfaces = 1

let g:go_fmt_command = "goimports"
let g:go_fmt_fail_silently = 1

nmap <F8> :TagbarToggle<CR>
let g:tagbar_type_go = {
    \ 'ctagstype' : 'go',
    \ 'kinds'     : [
        \ 'p:package',
        \ 'i:imports:1',
        \ 'c:constants',
        \ 'v:variables',
        \ 't:types',
        \ 'n:interfaces',
        \ 'w:fields',
        \ 'e:embedded',
        \ 'm:methods',
        \ 'r:constructor',
        \ 'f:functions'
    \ ],
    \ 'sro' : '.',
    \ 'kind2scope' : {
        \ 't' : 'ctype',
        \ 'n' : 'ntype'
    \ },
    \ 'scope2kind' : {
        \ 'ctype' : 't',
        \ 'ntype' : 'n'
    \ },
    \ 'ctagsbin'  : 'gotags',
    \ 'ctagsargs' : '-sort -silent'
\ }

au FileType go nmap <Leader>r <Plug>(go-rename)
au FileType go nmap <Leader>c <Plug>(go-coverage)
au FileType go nmap <Leader>d <Plug>(go-def)
au FileType go nmap <Leader>s <Plug>(go-implements)
au FileType go nmap <Leader>i <Plug>(go-info)
au FileType go nmap <Leader>gd <Plug>(go-doc)

" rust
set hidden
let g:racer_cmd = "racer"
let g:rustfmt_autosave = 1

