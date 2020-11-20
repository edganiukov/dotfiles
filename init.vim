call plug#begin('~/.config/nvim/plugged')

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

" Git
Plug 'mhinz/vim-signify'
Plug 'jreybert/vimagit'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/gv.vim'

" Lang
" installed manually
Plug 'edganiukov/vim-gol'
Plug 'plasticboy/vim-markdown'
Plug 'sebdah/vim-delve'
Plug 'rust-lang/rust.vim'

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
" set foldenable
set nofoldenable
set conceallevel=2

set number
set signcolumn=yes
set pumheight=20
set colorcolumn=141
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

" suppress the annoying 'match x of y', 'The only match', etc.
set shortmess+=c

if exists('$TMUX')
  let &t_SI = "\<Esc>Ptmux;\<Esc>\e[6 q\<Esc>\\"
  let &t_EI = "\<Esc>Ptmux;\<Esc>\e[2 q\<Esc>\\"
else
  let &t_SI = "\e[6 q"
  let &t_EI = "\e[2 q"
endif

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
"

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

" Expand opening-brace followed by ENTER
inoremap {<CR> {<CR>}<Esc>O

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
" close a window with qq<CR>
nnoremap <silent>qq :q

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
nnoremap <leader>id "=strftime("<%Y-%m-%d %a>")<CR>P
inoremap <leader>id <C-R>=strftime("<%Y-%m-%d %a>")<CR>

" Highlights
hi SignColumn ctermbg=NONE guibg=NONE
hi SpellBad cterm=undercurl ctermbg=NONE guibg=NONE

hi Todo ctermbg=NONE guibg=NONE cterm=NONE gui=NONE
hi Error ctermbg=NONE guibg=NONE cterm=NONE gui=NONE

" hi NormalFloat

" trailing whitespaces
match ErrorMsg '\s\+$'

" Quickly open/reload vim
nnoremap <leader>ev :vsplit $MYVIMRC<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>

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


" Plug 'majutsushi/tagbar'
"
nmap <F4> :TagbarToggle<CR>
let g:tagbar_sort = 0


" Plug 'tpope/vim-markdown'
"
autocmd BufNewFile,BufReadPost *.md set filetype=markdown
au FileType markdown setlocal spell sw=2 sts=2 ts=2 syntax=markdown conceallevel=2

let g:vim_markdown_fenced_languages = [
  \ 'vim',
  \ 'bash=sh',
  \ 'go',
  \ 'py=python',
  \ 'rs=rust',
  \ 'c',
  \ 'cpp',
  \ 'yaml',
  \ ]

let g:vim_markdown_conceal = 2
let g:vim_markdown_conceal_code_blocks = 0
let g:vim_markdown_math = 1
let g:tex_conceal = ""

let g:vim_markdown_strikethrough = 1
let g:vim_markdown_autowrite = 1
let g:vim_markdown_edit_url_in = 'current'
let g:vim_markdown_follow_anchor = 1

let g:vim_markdown_new_list_item_indent = 2


" Plug 'junegunn/fzf.vim'
"
set rtp+=/usr/local/opt/fzf
let g:fzf_layout = { 'down': '~40%' }
" Empty value to disable preview window altogether
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


" https://github.com/BurntSushi/ripgrep
nnoremap <leader>s :Rg<CR>

command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --colors "path:fg:190,220,255" --colors "line:fg:128,128,128" --smart-case '.shellescape(<q-args>),
  \ 1, { 'options': '--color hl:72,hl+:167 --nth 2..' }, 0)

nnoremap <leader>b :Buffers<CR>
nnoremap <leader>f :Files<CR>


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
  \ '\.DS_Store',
  \ '\.git$',
  \ '\.test$',
  \ '\.pyc$',
  \ '\.idea',
  \ '\.stfolder'
  \]

let NERDTreeMapActivateNode = '<Space>'
let g:NERDTreeWinSize = 40

let g:NERDTreeDirArrowExpandable = '+'
let g:NERDTreeDirArrowCollapsible = '-'

map <F3> :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif


" Plug 'jreybert/vimagit'
"
let g:magit_commit_title_limit = 80


" Plug 'junegunn/gv.vim'
"
nnoremap <leader>gv :GV<CR>


"Plug 'Shougo/echodoc.vim'
"
let g:echodoc#enable_at_startup = 1
let g:echodoc#type = 'echo'
hi link EchoDocFloat Pmenu

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
autocmd FileType go,rust,c,cpp setlocal omnifunc=lsp#complete
inoremap <leader>f <C-x><C-o>

" Plug 'prabirshrestha/vim-lsp'
"

" golang.org/x/tools/cmd/gopls
au User lsp_setup call lsp#register_server({
  \ 'name': 'gopls',
  \ 'cmd': {server_info->['gopls', 'serve']},
  \ 'root_uri':{server_info->lsp#utils#path_to_uri(
    \ lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), ['go.mod'])
    \ )},
  \ 'workspace_config': {'gopls': {'codelens': {'generate': 'false', 'gc_details': 'true'}}},
  \ 'allowlist': ['go'],
  \ })

" https://github.com/rust-lang/rls
au User lsp_setup call lsp#register_server({
  \ 'name': 'rls',
  \ 'cmd': {server_info->['rustup', 'run', 'stable', 'rls']},
  \ 'root_uri':{server_info->lsp#utils#path_to_uri(
    \ lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), ['Cargo.toml'])
    \ )},
  \ 'workspace_config': {'rust': {'clippy_preference': 'on'}},
  \ 'allowlist': ['rust'],
  \ })

" https://github.com/MaskRay/ccls
au User lsp_setup call lsp#register_server({
  \ 'name': 'ccls',
  \ 'cmd': {server_info->['ccls']},
  \ 'root_uri':{server_info->lsp#utils#path_to_uri(
    \ lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), ['.ccls'])
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
  \ 'allowlist': ['python'],
  \ })

let g:lsp_auto_enable = 1
let g:lsp_preview_keep_focus = 1

let g:lsp_diagnostics_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_signs_enabled = 1
let g:lsp_highlights_enabled = 1
let g:lsp_textprop_enabled = 0
let g:lsp_virtual_text_enabled = 0

let g:lsp_highlight_references_enabled = 0

let g:lsp_text_edit_enabled = 1
let g:lsp_insert_text_enabled = 0

let g:lsp_signs_error = {'text': 'x'}
let g:lsp_signs_warning = {'text': '>'}
let g:lsp_signs_information = {'text': '!'}
let g:lsp_signs_hint = {'text': '?'}

let g:lsp_log_verbose = 1
let g:lsp_log_file = expand('/tmp/lsp.log')

" highlight PopupWindow guibg=#fdf6e3

nnoremap <silent> gd :LspDefinition<CR>
nnoremap <silent> gds :sp<cr>:LspDefinition<cr>
nnoremap <silent> gdv :vsp<cr>:LspDefinition<cr>
nnoremap <silent> gtd :LspTypeDefinition<CR>
nnoremap <silent> gdc :LspDeclaration<cr>
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

" autocmd FileType go,rust,c,cpp
"   \ autocmd BufWrite <buffer> :LspDocumentFormatSync


" Plug 'rust-lang/rust.vim'
"
let g:rustfmt_autosave = 1
au FileType rust nnoremap gt :RustTest<CR>


" Plug 'edganiukov/vim-gol'
"
let g:go_fmt_command = "goimports"
let g:go_fmt_fail_silently = 1
let g:go_fmt_autosave = 1


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
au FileType go setlocal noexpandtab

au FileType vim setlocal sw=2 sts=2 ts=2
au FileType vim setlocal sw=2 sts=2 ts=2

au FileType yaml setlocal sw=2 sts=2 ts=2
au FileType json setlocal sw=2 sts=2 ts=2
au FileType conf setlocal sw=2 sts=2 ts=2
au FileType gitcommit setlocal spell tw=80 cc=81
au FileType rst setlocal spell tw=80 cc=81
au FileType markdown setlocal spell tw=79 cc=81

au BufRead,BufNewFile *.toml setlocal ft=conf
au BufRead,BufNewFile *.conf setlocal ft=conf
au BufRead,BufNewFile *.slide setlocal ft=markdown
au BufNewFile,BufRead Jenkinsfile set filetype=groovy

" Jinja templates
au BufRead,BufNewFile *.yml.j2 setlocal ft=yaml
au BufRead,BufNewFile *.conf.j2 setlocal ft=conf
au BufRead,BufNewFile *.sh.j2 setlocal ft=sh

au BufRead,BufNewFile *.yml.tmpl setlocal ft=yaml
au BufRead,BufNewFile *.conf.tmpl setlocal ft=conf
au BufRead,BufNewFile *.sh.tmpl setlocal ft=sh
au BufRead,BufNewFile *.toml.tmpl setlocal ft=conf
