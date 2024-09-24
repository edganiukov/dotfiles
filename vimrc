vim9script

plug#begin('~/.vim/plugged')

# Plugins
# https://github.com/junegunn/vim-plug
Plug 'https://git.sr.ht/~gnkv/vim-colors-off'

# Basic
Plug 'jlanzarotta/bufexplorer'
Plug 'tpope/vim-commentary'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'preservim/nerdtree'

Plug 'tpope/vim-fugitive'
Plug 'mhinz/vim-signify'

Plug 'https://git.sr.ht/~gnkv/vim-gol'
Plug 'sebdah/vim-delve'

# LSP
Plug 'prabirshrestha/vim-lsp'
Plug 'lifepillar/vim-mucomplete'

plug#end()

# Standard VIM TUI Settings
set nocompatible
filetype off

filetype plugin indent on
syntax on

set t_Co=256
set t_ut=

colorscheme off

set encoding=utf-8

set wildmenu
set wildoptions-=pum
set wildignore+=*/.git/*,*/.direnv/*
set completeopt=menuone,popup,noselect

set nospell
set hidden
set noerrorbells
set novisualbell
set t_vb=

set modeline
set modelines=1
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

set scrolljump=1
set scrolloff=4
set backspace=2

set conceallevel=0
set nofoldenable

set number
set signcolumn=yes
set pumheight=20
set textwidth=120
set colorcolumn=120
set cursorline
set cursorcolumn

set pastetoggle=<F2>
set nopaste
set clipboard=unnamedplus

set listchars=tab:>\ ,nbsp:.,trail:.
set list

# Formatting options.
set wrap
set formatoptions=qrn1j

set autoread

set autoindent
set smartindent
set noexpandtab
set tabstop=4
set shiftwidth=4
set shiftround

set splitright
set splitbelow

set shortmess+=c
set laststatus=2

def g:StatusLineMode(): string
	var modes = {
		'n': 'NORMAL',
		'i': 'INSERT',
		'R': 'REPLACE',
		'v': 'VISUAL',
		'V': 'V-LINE',
		"\<C-v>": 'V-BLOCK',
		'c': 'COMMAND',
		's': 'SELECT',
		'S': 'S-LINE',
		"\<C-s>": 'S-BLOCK',
		't': 'TERMINAL'
	}
	return get(modes, mode(), '[NONE]')
enddef

set statusline=
set statusline+=%#Comment#[%n]%*
set statusline+=%#PmenuSel#\ %{g:StatusLineMode()}%{&paste?":PASTE":""}\ %*	# mode and paste indicator
set statusline+=\ %.50f\ %m\ %r	# filepath and modified flag

set statusline+=%=
set statusline+=%{&ff}	# file format
set statusline+=\ \|\ %{&fenc!=#""?&fenc:&enc}	# file enconding
set statusline+=\ \|\ %{&ft!=#""?&ft:"[none]"}	# file type
set statusline+=\ \|\ %p%%\ %l:%c\ %* # percentage and lineinfo

# Fix cursor in INSERT mode.
&t_SI = "\e[5 q"
&t_EI = "\e[2 q"

# Non-plugin Keybindings:
# yank to the EOL
nnoremap Y y$
# delete without yanking
nnoremap <leader>d "_d
vnoremap <leader>d "_d
# replace selected text without yanking
vnoremap <leader>p "_dP"

noremap j gj
noremap k gk

# indent
nmap < <<
nmap > >>
vnoremap < <gv
vnoremap > >gv

nnoremap <F5> :set list!<CR>
inoremap <F5> <Esc>:set list!<CR>a
nnoremap <leader><space> :nohlsearch<CR>

# quickfix close
nnoremap <silent>qc :cclose<CR>
nnoremap <silent>qf :copen<CR>

# quickfix switch
nnoremap <Down> :cn!<CR>
nnoremap <Up> :cp!<CR>
nnoremap qn :cn!<CR>
nnoremap qp :cp!<CR>

# buffers switch
nnoremap fn :bn!<CR>
nnoremap fp :bp!<CR>
nnoremap fd :bd<cr>

# window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

# disable arrows
# noremap <Up> <NOP>
# noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>

inoremap <Up> <NOP>
inoremap <Down> <NOP>
inoremap <Left> <NOP>
inoremap <Right> <NOP>

# expand opening-brace
inoremap {<CR> {<CR>}<Esc>O

# reload vimrc
nnoremap <leader>sv :source $MYVIMRC<CR>
nnoremap <leader>t  :ter<CR>

cnoreabbrev Wq wq
cnoreabbrev Wa wa


hi SignColumn ctermbg=NONE guibg=NONE
hi SpellBad cterm=undercurl ctermbg=NONE guibg=NONE
hi Todo ctermbg=NONE guibg=NONE cterm=NONE gui=NONE
hi Error ctermbg=NONE guibg=NONE cterm=NONE gui=NONE
# trailing whitespaces
match ErrorMsg '\s\+$'


# Plug 'tpope/vim-commentary'
#
augroup commentstring
	autocmd FileType c,h setlocal commentstring=//\ %s
augroup END

# Plug 'preservim/nerdtree'
#
g:NERDTreeDirArrows = 1
g:NERDTreeMinimalUI = 1
g:NERDTreeShowHidden = 1
g:NERDTreeMinimalMenu = 1

g:NERDTreeMapActivateNode = '<Space>'
g:NERDTreeWinSize = 40

g:NERDTreeDirArrowExpandable = '+'
g:NERDTreeDirArrowCollapsible = '-'

g:NERDTreeIgnore = [
	'^\.git$',
	'^\.direnv$',
	'^target$',
]

map <F3> :NERDTreeToggle<CR>

autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') | quit | endif


# Plug 'mhinz/vim-signify'
#
g:signify_vcs_list = ['git']
g:signify_realtime = 1
g:signify_sign_show_count = 0

g:signify_sign_add = '+'
g:signify_sign_delete = '_'
g:signify_sign_delete_first_line = '‾'
g:signify_sign_change = '~'
g:signify_sign_changedelete = g:signify_sign_change

hi SignifySignAdd ctermbg=NONE guibg=NONE ctermfg=green guifg=green
hi SignifySignChange ctermbg=NONE guibg=NONE ctermfg=yellow guifg=yellow
hi SignifySignDelete ctermbg=NONE guibg=NONE ctermfg=red guifg=red


# Plug 'ctrlpvim/ctrlp.vim'
#
g:ctrlp_working_path_mode = 'ra'
g:ctrlp_types = ['fil', 'buf']
g:ctrlp_user_command = 'rg --files --sort=none'
g:ctrlp_switch_buffer = 'e'
g:ctrlp_max_height = 20

# ripgrep
set grepprg=rg\ --vimgrep
set grepformat=%f:%l:%c:%m,%f:%l:%m
cnoreabbrev <expr> grep 'silent grep'
cnoreabbrev <expr> lgrep 'silent lgrep'

nnoremap <leader>g :silent grep! <C-R><C-W><CR>

augroup quickfix
	autocmd!
	autocmd QuickFixCmdPost [^l]* cwindow | call setqflist([], 'a')
	autocmd QuickFixCmdPost [l]* lwindow | call setqflist([], 'a')
augroup END


# Plug 'lifepillar/vim-mucomplete'
#
g:mucomplete#enable_auto_at_startup = 1
g:mucomplete#completion_delay = 100
g:mucomplete#reopen_immediately = 1

g:mucomplete#chains = {
	default: ['omni', 'keyn'],
	sql: ['keyn']
}
g:mucomplete#can_complete = {
	default: {
		omni: (t) => strlen(&l:omnifunc) > 0 && t =~# '\%(\k\|->\|::\|\.\)$',
	}
}

# mucomplete + vim-lsp
autocmd FileType go,rust setlocal omnifunc=lsp#complete
inoremap <leader>c <C-x><C-o>


# Plug 'prabirshrestha/vim-lsp'
#
# golang.org/x/tools/cmd/gopls
var gols = {
	name: 'gopls',
	cmd: (server_info) => ['gopls', 'serve'],
	root_uri: (server_info) => lsp#utils#path_to_uri(
		lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), ['go.mod', 'go.work'])
	),
	workspace_config: {
		gopls: {
			codelenses: {generate: v:false, gc_details: v:true},
			hoverKind: 'FullDocumentation',
			linksInHover: v:false,
			staticcheck: v:true,
		},
	},
	allowlist: ['go'],
	languageId: (server_info) => 'filetype',
}
au User lsp_setup lsp#register_server(gols)

# https://github.com/rust-lang/rust-analyzer
var rls = {
	name: 'rls',
	cmd: (server_info) => ['rust-analyzer'],
	root_uri: (server_info) => lsp#utils#path_to_uri(
		lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), ['Cargo.toml'])
	),
	initialization_options: {
		cargo: {
			buildScripts: {
				enable: v:true,
			},
		},
		procMacro: {
			enable: v:true,
		},
	},
	allowlist: ['rust'],
}
au User lsp_setup lsp#register_server(rls)

g:lsp_fold_enabled = 0
g:lsp_text_edit_enabled = 0
g:lsp_semantic_enabled = 0

g:lsp_diagnostics_echo_cursor = 1
g:lsp_diagnostics_virtual_text_enabled = 0

g:lsp_diagnostics_signs_error = {'text': 'x'}
g:lsp_diagnostics_signs_warning = {'text': 'w'}
g:lsp_diagnostics_signs_information = {'text': '@'}
g:lsp_diagnostics_signs_hint = {'text': '*'}

g:lsp_document_code_action_signs_hint = {'text': '>'}

g:lsp_format_sync_timeout = 1000

g:lsp_show_message_log_level = 'none'
g:lsp_log_file = expand('/tmp/lsp.log')

nnoremap <silent> gd :LspDefinition<CR>
nnoremap <silent> gds :sp<cr>:LspDefinition<cr>
nnoremap <silent> gdv :vsp<cr>:LspDefinition<cr>
nnoremap <silent> gtd :LspTypeDefinition<CR>
nnoremap <silent> gdc :LspDeclaration<cr>
nnoremap <silent> gi :LspImplementation<cr>
nnoremap <silent> gr :LspRename<CR>
nnoremap <silent> gf :LspDocumentFormat<CR>
nnoremap <silent> grf :LspDocumentRangeFormat<CR>
nnoremap <silent> ga :LspCodeAction --ui=float<CR>
nnoremap <silent> gl :LspCodeLens<CR>
nnoremap <silent> gn :LspNextError<CR>
nnoremap <silent> gp :LspPreviousError<CR>
nnoremap <silent> gx :LspReferences<CR>
nnoremap <silent> gh :LspHover<CR>
nnoremap <silent> gs :LspWorkspaceSymbol<CR>
nnoremap <silent> gth :LspTypeHierarchy<CR>

augroup autoformat
	autocmd FileType go,rust,zig autocmd BufWritePre <buffer> :LspDocumentFormatSync
	autocmd FileType go autocmd BufWritePre <buffer>
		\ execute('LspCodeActionSync source.organizeImports')

	autocmd FileType proto autocmd BufWritePre <buffer> g:Format('clang-format -assume-filename=foobar.proto')
	# autocmd FileType c,h autocmd BufWritePre <buffer> g:Format('clang-format -assume-filename=foobar.c')
augroup END

def g:Format(formatter: string)
	var winview = winsaveview()

	var content = join(getbufline('%', 1, '$'), "\n")
	var formatted = systemlist(formatter, content)
	if v:shell_error == 0
		deletebufline('%', 1, '$')
		setline(1, [])
		setbufline('%', 1, formatted)
	else
		echoerr printf('Formatting failed: %s', formatted)
	endif

	winrestview(winview)
enddef

command! -bang -nargs=* LspStartServer lsp#activate()

# Plug 'sebdah/vim-delve'
#
hi DlvPoint term=standout ctermbg=117 ctermfg=0 guibg=#BAD4F5 guifg=Black
g:delve_breakpoint_sign_highlight = 'DlvPoint'
g:delve_tracepoint_sign_highlight = 'DlvPoint'
g:delve_breakpoint_sign = '>>'
g:delve_tracepoint_sign = '||'

nnoremap <silent> drt :DlvTest<CR>
nnoremap <silent> drd :DlvDebug<CR>
nnoremap <silent> dtb :DlvToggleBreakpoint<CR>
nnoremap <silent> dtt :DlvToggleTracepoint<CR>


# Filetype config.
augroup filetypedetect
	au FileType python setlocal et sts=4 tw=80 cc=80
	au FileType yaml setlocal et sw=2 sts=2 ts=2
	au FileType proto setlocal et sts=4

	au FileType rst,markdown,text setlocal tw=80 cc=80 spell
	au FileType mail setlocal tw=72 cc=72 spell
	au FileType gitcommit setlocal tw=72 cc=72 spell
	# Resize quickfix
	au FileType qf resize 20
augroup END
