call plug#begin('~/.vim/plugged')

" Plugins
" https://github.com/junegunn/vim-plug
Plug 'edganiukov/vim-colors-off'

" Basic
Plug 'itchyny/lightline.vim'
Plug 'jlanzarotta/bufexplorer'
Plug 'tpope/vim-commentary'
Plug 'junegunn/fzf.vim'
Plug 'preservim/tagbar'
Plug 'scrooloose/nerdtree'
Plug 'chaoren/vim-wordmotion'

" Git
Plug 'mhinz/vim-signify'
Plug 'jreybert/vimagit'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/gv.vim'

" Lang
Plug 'edganiukov/vim-gol'
Plug 'plasticboy/vim-markdown'
Plug 'sebdah/vim-delve'

" LSP
Plug 'prabirshrestha/vim-lsp'
" Completion
Plug 'Shougo/echodoc.vim'
Plug 'lifepillar/vim-mucomplete'

call plug#end()

" Standard VIM TUI Settings
set nocompatible
filetype off

filetype plugin indent on
syntax on

set t_Co=256
set t_ut=
set termguicolors
set bg=dark

colorscheme off

if exists('$TMUX')
  let &t_SI = "\<Esc>Ptmux;\<Esc>\e[6 q\<Esc>\\"
  let &t_EI = "\<Esc>Ptmux;\<Esc>\e[2 q\<Esc>\\"
else
  let &t_SI = "\e[6 q"
  let &t_EI = "\e[2 q"
endif

" cmd autocomplete
set wildmenu
set wildoptions-=pum
set completeopt=menuone,noselect

set nospell
set hidden
set noerrorbells
set novisualbell
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
set conceallevel=2

set number
set signcolumn=yes
set pumheight=20
set textwidth=120
set colorcolumn=121
set cursorline

set pastetoggle=<F2>
set nopaste

" copy to the system clipboard
set clipboard=unnamedplus

set listchars=tab:>\ ,nbsp:.,trail:.
set list

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

set laststatus=2
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

" Non-plugin Keybindings:
" yank to the EOL
nnoremap Y y$
" delete without yanking
nnoremap <leader>d "_d
vnoremap <leader>d "_d
" replace selected text without yanking
vnoremap <leader>p "_dP"

" quotes
vnoremap <Leader>q" di""<Esc>P
vnoremap <Leader>q' di''<Esc>P
vnoremap <Leader>q` di``<Esc>P
vnoremap <Leader>q( di()<Esc>P
vnoremap <Leader>q[ di[]<Esc>P
vnoremap <Leader>q{ di{}<Esc>P
vnoremap <Leader>q< di<><Esc>P

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
" close a window with qq<CR>
nnoremap <silent>qq :q
" quickfix switch
nnoremap qn :cn!<CR>
nnoremap qp :cp!<CR>
" buffers switch
nnoremap fn :bn!<CR>
nnoremap fp :bp!<CR>

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
nnoremap <leader>id "=strftime("<%Y-%m-%d %a>")<CR>P
inoremap <leader>id <C-R>=strftime("<%Y-%m-%d %a>")<CR>

" semicolon in the EOL
" nnoremap ;; A;<Esc>
" inoremap ;; <C-o>A;
"
" expand opening-brace
inoremap {<CR> {<CR>}<Esc>O

" open/reload vim.rc
nnoremap <leader>ev :vsplit $MYVIMRC<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>

" Highlights
hi SignColumn ctermbg=NONE guibg=NONE
hi SpellBad cterm=undercurl ctermbg=NONE guibg=NONE

hi Todo ctermbg=NONE guibg=NONE cterm=NONE gui=NONE
hi Error ctermbg=NONE guibg=NONE cterm=NONE gui=NONE

" trailing whitespaces
match ErrorMsg '\s\+$'


" Plug 'mhinz/vim-signify'
"
let g:signify_vcs_list = ['git']
let g:signify_realtime = 1
let g:signify_cursorhold_insert = 1
let g:signify_cursorhold_normal = 1
let g:signify_update_on_bufenter = 0
let g:signify_update_on_focusgained = 1
let g:signify_sign_show_count = 0

let g:signify_sign_add = '+'
let g:signify_sign_delete = '_'
let g:signify_sign_delete_first_line = '‾'
let g:signify_sign_change = '~'
let g:signify_sign_changedelete = g:signify_sign_change

hi SignifySignAdd ctermbg=NONE guibg=NONE ctermfg=green guifg=green
hi SignifySignChange ctermbg=NONE guibg=NONE ctermfg=yellow guifg=yellow
hi SignifySignDelete ctermbg=NONE guibg=NONE ctermfg=red guifg=red


" Plug 'jreybert/vimagit'
"
let g:magit_commit_title_limit = 80
nnoremap vm :Magit<CR>


" Plug 'junegunn/gv.vim'
"
nnoremap vg :GV<CR>


" Plug 'majutsushi/tagbar'
"
nmap <F4> :TagbarToggle<CR>
let g:tagbar_sort = 0


" Plug 'tpope/vim-markdown'
"
let g:vim_markdown_fenced_languages = [
  \ 'go',
  \ 'python',
  \ 'rust',
  \ 'c',
  \ 'cpp',
  \ 'bash=sh',
  \ 'yaml=yml',
  \ ]

let g:vim_markdown_conceal = 1
let g:vim_markdown_conceal_code_blocks = 1
let g:vim_markdown_math = 1
let g:vim_markdown_new_list_item_indent = 2


" Plug 'junegunn/fzf.vim'
"
set rtp+=/usr/local/opt/fzf
let g:fzf_layout = { 'down': '~40%' }
" disable preview window
let g:fzf_preview_window = ''

" match vim colorscheme
let g:fzf_colors = {
  \ 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'PreProc'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment']
  \ }

nnoremap <leader>b :Buffers<CR>
nnoremap <leader>f :Files<CR>
nnoremap <leader>h :Hist<CR>

" https://github.com/BurntSushi/ripgrep
nnoremap <leader>s :Rg<CR>
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
    \ 'rg --column --line-number
    \ --no-heading --color=always
    \ --colors "path:fg:190,220,255" --colors "line:fg:128,128,128" --smart-case '
    \ .shellescape(<q-args>),
  \ 1, { 'options': '--color hl:72,hl+:167 --nth 2..' }, 0)


" Plug 'itchyny/lightline'
"
let g:bufferline_echo = 0
let g:lightline = {
  \ "colorscheme": "jellybeans",
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
let NERDTreeDirArrows = 1
let NERDTreeMinimalUI = 1
let NERDTreeShowHidden = 1
let NERDTreeIgnore = [
  \ '\.git$',
  \ '\.test$',
  \ '\.pyc$',
  \ ]

let g:NERDTreeMapActivateNode = '<Space>'
let g:NERDTreeWinSize = 40

let g:NERDTreeDirArrowExpandable = '+'
let g:NERDTreeDirArrowCollapsible = '-'

map <F3> :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1
      \ && exists("b:NERDTree") 
      \ && b:NERDTree.isTabTree()) | q | endif


"Plug 'Shougo/echodoc.vim'
"
let g:echodoc#enable_at_startup = 1
let g:echodoc#type = 'echo'


" Plug 'lifepillar/vim-mucomplete'
"
let g:mucomplete#enable_auto_at_startup = 1
let g:mucomplete#completion_delay= 0
let g:mucomplete#reopen_immediately = 1

let g:mucomplete#chains = {}
let g:mucomplete#chains.default = ['omni']
let g:mucomplete#can_complete = {
  \ 'default': {
    \ 'omni': { t -> strlen(&l:omnifunc) > 0 && t =~# '\%(\k\|->\|::\|\.\)$' }
    \ }
  \ }

" mucomplete + vim-lsp
autocmd FileType go,rust,c,cpp,python setlocal omnifunc=lsp#complete
inoremap <leader>c <C-x><C-o>


" Plug 'prabirshrestha/vim-lsp'
"
" golang.org/x/tools/cmd/gopls
au User lsp_setup call lsp#register_server({
  \ 'name': 'gopls',
  \ 'cmd': {server_info->['gopls', 'serve']},
  \ 'root_uri':{server_info->lsp#utils#path_to_uri(
    \ lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), ['go.mod'])
    \ )},
  \ 'workspace_config': {'gopls': {
      \ 'codelenses': {'generate': v:false, 'gc_details': v:true},
      \ 'hoverKind': 'FullDocumentation',
      \ 'experimentalWorkspaceModule': v:true,
  \ }},
  \ 'allowlist': ['go'],
  \ })

" https://github.com/rust-lang/rls
au User lsp_setup call lsp#register_server({
  \ 'name': 'rls',
  \ 'cmd': {server_info->['rustup', 'run', 'stable', 'rls']},
  \ 'root_uri':{server_info->lsp#utils#path_to_uri(
    \ lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), ['Cargo.toml'])
    \ )},
  \ 'workspace_config': {'rust': {
      \ 'clippy_preference': 'on',
  \ }},
  \ 'allowlist': ['rust'],
  \ })

" https://github.com/MaskRay/ccls
au User lsp_setup call lsp#register_server({
  \ 'name': 'ccls',
  \ 'cmd': {server_info->['ccls']},
  \ 'root_uri':{server_info->lsp#utils#path_to_uri(
    \ lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), ['.ccls', 'compile_commands.json'])
    \ )},
  \ 'initialization_options': {'cache': {'directory': expand('~/.cache/ccls')}},
  \ 'allowlist': ['c', 'cpp'],
  \ })

" Alternative: clangd
"
" au User lsp_setup call lsp#register_server({
"   \ 'name': 'clangd',
"   \ 'cmd': {server_info->['clangd', '-background-index']},
"   \ 'allowlist': ['c', 'cpp'],
"   \ })

" https://github.com/palantir/python-language-server
au User lsp_setup call lsp#register_server({
  \ 'name': 'pyls',
  \ 'cmd': {server_info->['pyls']},
  \ 'root_uri':{server_info->lsp#utils#path_to_uri(
    \ lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), ['.git'])
    \ )},
  \ 'workspace_config': {'pyls': {
      \ 'configurationSources': ['flake8'],
  \ }},
  \ 'allowlist': ['python'],
  \ })

" https://github.com/fwcd/kotlin-language-server
" au User lsp_setup call lsp#register_server({
"   \ 'name': 'kls',
"   \ 'cmd': {server_info->['kotlin-language-server']},
"   \ 'whitelist': ['kotlin']
"   \ })

let g:lsp_fold_enabled = 0
let g:lsp_text_edit_enabled = 0
let g:lsp_insert_text_enabled = 0

let g:lsp_diagnostics_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_diagnostics_virtual_text_enabled = 0

let g:lsp_diagnostics_signs_error = {'text': 'x'}
let g:lsp_diagnostics_signs_warning = {'text': '>'}
let g:lsp_diagnostics_signs_information = {'text': '@'}
let g:lsp_diagnostics_signs_hint = {'text': '*'}

let g:lsp_log_file = expand('/tmp/lsp.log')

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

" autocmd FileType c,cpp
"   \ autocmd BufWrite <buffer> :LspDocumentFormatSync

autocmd FileType go,rust,python
  \ autocmd BufWrite <buffer> :LspDocumentFormatSync


" Plug 'sebdah/vim-delve'
"
hi DlvPoint term=standout ctermbg=117 ctermfg=0 guibg=#BAD4F5 guifg=Black
let g:delve_breakpoint_sign_highlight = 'DlvPoint'
let g:delve_tracepoint_sign_highlight = 'DlvPoint'
let g:delve_breakpoint_sign = '>>'
let g:delve_tracepoint_sign = '||'

nnoremap <silent> drt :DlvTest<CR>
nnoremap <silent> drd :DlvDebug<CR>
nnoremap <silent> dtb :DlvToggleBreakpoint<CR>
nnoremap <silent> dtt :DlvToggleTracepoint<CR>


" General: filetype config
"
au BufRead,BufNewFile *.toml setlocal ft=conf
au BufRead,BufNewFile *.conf setlocal ft=conf
au BufRead,BufNewFile *.slide setlocal ft=markdown
au BufNewFile,BufRead Jenkinsfile set filetype=groovy

au BufRead,BufNewFile *.yml.tmpl setlocal ft=yaml
au BufRead,BufNewFile *.conf.tmpl setlocal ft=conf
au BufRead,BufNewFile *.sh.tmpl setlocal ft=sh
au BufRead,BufNewFile *.toml.tmpl setlocal ft=conf

au FileType go setlocal noexpandtab tw=100 cc=101
au FileType python setlocal sw=4 sts=4 ts=4 tw=100 cc=101
au FileType groovy setlocal noexpandtab

au FileType vim setlocal sw=2 sts=2 ts=2
au FileType yaml setlocal sw=2 sts=2 ts=2
au FileType json setlocal sw=2 sts=2 ts=2
au FileType conf setlocal sw=2 sts=2 ts=2
au FileType gitcommit setlocal spell tw=80 cc=81

au FileType rst setlocal spell tw=80 cc=81
au FileType markdown setlocal spell sw=2 sts=2 ts=2 tw=80 cc=81
