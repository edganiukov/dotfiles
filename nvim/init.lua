local opt = vim.opt

vim.g.NERDTreeDirArrows = 1
vim.g.NERDTreeMinimalUI = 1
vim.g.NERDTreeShowHidden = 1
vim.g.NERDTreeMinimalMenu = 1
vim.g.NERDTreeMapActivateNode = '<Space>'
vim.g.NERDTreeWinSize = 40
vim.g.NERDTreeDirArrowExpandable = '+'
vim.g.NERDTreeDirArrowCollapsible = '-'
vim.g.NERDTreeIgnore = {
  '^\\.git$',
  '^\\.direnv$',
  '^\\.zig-*',
  '^\\.localdev-tmp',
  '^\\.stfolder',
  '^\\.turbo',
}

assert(vim.pack, 'This config uses vim.pack and requires Neovim 0.12+')
vim.pack.add({
  'https://github.com/preservim/nerdtree',
  'https://github.com/jlanzarotta/bufexplorer',
  'https://github.com/tpope/vim-fugitive',
  'https://github.com/airblade/vim-gitgutter',
}, { confirm = false, load = true })

pcall(vim.cmd.colorscheme, 'off')

local separator_hl = { fg = '#303030', bg = '#181818', ctermfg = 236, ctermbg = 234 }
for _, group in ipairs({ 'VertSplit', 'WinSeparator' }) do
  vim.api.nvim_set_hl(0, group, separator_hl)
end
vim.api.nvim_set_hl(0, 'LspHoverNormal', { fg = '#C6C6C6', bg = '#303030', ctermfg = 251, ctermbg = 236 })
vim.api.nvim_set_hl(0, 'LspHoverBorder', { fg = '#545454', bg = '#303030', ctermfg = 240, ctermbg = 236 })

if not vim.lsp.util._off_open_floating_preview then
  vim.lsp.util._off_open_floating_preview = vim.lsp.util.open_floating_preview
  vim.lsp.util.open_floating_preview = function(contents, syntax, opts, ...)
    local bufnr, winid = vim.lsp.util._off_open_floating_preview(contents, syntax, opts, ...)
    if opts and opts.focus_id == 'textDocument/hover' and winid then
      vim.wo[winid].winhighlight = 'NormalFloat:LspHoverNormal,FloatBorder:LspHoverBorder'
    end
    return bufnr, winid
  end
end

opt.wildoptions:remove('pum')
opt.wildignore:append({ '.git/', '.direnv/' })
opt.completeopt = { 'menuone', 'noselect' }

opt.visualbell = true
opt.modelines = 0
opt.mouse = 'a'

opt.ignorecase = true
opt.smartcase = true

opt.writebackup = false
opt.swapfile = false

opt.showmode = false
opt.showmatch = true
opt.matchtime = 2

opt.scrolloff = 4
opt.foldenable = false

opt.number = true
opt.signcolumn = 'yes'
opt.pumheight = 20
opt.textwidth = 120
opt.linebreak = true
opt.colorcolumn = '120'
opt.cursorline = true
opt.cursorcolumn = true

opt.clipboard = 'unnamedplus'
opt.listchars = { tab = '> ', nbsp = '.', trail = '.' }
opt.list = true

opt.formatoptions = 'rq1'

opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.shiftround = true

opt.splitright = true
opt.splitbelow = true
opt.shortmess:append('c')
opt.updatetime = 100

local modes = {
  n = 'NORMAL',
  i = 'INSERT',
  R = 'REPLACE',
  v = 'VISUAL',
  V = 'V-LINE',
  ['\022'] = 'V-BLOCK',
  c = 'COMMAND',
  s = 'SELECT',
  S = 'S-LINE',
  ['\019'] = 'S-BLOCK',
  t = 'TERMINAL',
}

function _G.statusline_mode()
  return modes[vim.fn.mode()] or '[NONE]'
end

function _G.git_status()
  if vim.fn.exists('*GitGutterGetHunkSummary') == 0 then
    return ''
  end

  local ok, summary = pcall(vim.fn.GitGutterGetHunkSummary)
  if not ok or type(summary) ~= 'table' then
    return ''
  end

  return string.format('+%d ~%d -%d', summary[1] or 0, summary[2] or 0, summary[3] or 0)
end

opt.statusline = table.concat({
  '%#Comment#[%n]%*',
  "%#PmenuSel# %{v:lua.statusline_mode()}%{&paste?':PASTE':''} %*",
  ' %.50f %m %r',
  '%{v:lua.git_status()}',
  '%=',
  '%{&ff}',
  ' | %{&fenc!=#""?&fenc:&enc}',
  ' | %{&ft!=#""?&ft:"[none]"}',
  ' | %p%% %l:%c %*',
})

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local autoreload = augroup('autoreload', { clear = true })
autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
  group = autoreload,
  command = 'checktime',
})
autocmd('FileChangedShellPost', {
  group = autoreload,
  callback = function()
    vim.notify('File has been changed. Buffer reloaded.')
  end,
})

local function map(mode, lhs, rhs, opts_map)
  vim.keymap.set(mode, lhs, rhs, opts_map or {})
end

map('n', 'Y', 'y$')
map('v', 'p', '"_dP')
map('n', '<leader>d', '"_d')

map({ 'n', 'x' }, 'j', 'gj')
map({ 'n', 'x' }, 'k', 'gk')

map('n', '<', '<<')
map('n', '>', '>>')
map('v', '<', '<gv')
map('v', '>', '>gv')

map('n', '<leader><space>', ':nohlsearch<CR>', { silent = true })

map('n', 'qc', ':cclose<CR>', { silent = true })
-- map('n', 'qf', ':copen<CR>', { silent = true })
map('n', '<Down>', ':cn!<CR>')
map('n', '<Up>', ':cp!<CR>')
map('n', 'qn', ':cn!<CR>')
map('n', 'qp', ':cp!<CR>')

map('n', 'fn', ':bn!<CR>')
map('n', 'fp', ':bp!<CR>')
map('n', 'fd', ':bd<CR>')

map({ 'n', 'v' }, '<Left>', '<NOP>')
map({ 'n', 'v' }, '<Right>', '<NOP>')
map('i', '<Up>', '<NOP>')
map('i', '<Down>', '<NOP>')
map('i', '<Left>', '<NOP>')
map('i', '<Right>', '<NOP>')

map('i', '{<CR>', '{}<Left><CR><Esc>O')

map('n', '<A-Down>', ':m+<CR>=gv')
map('n', '<A-Up>', ':m-2<CR>=gv')
map('v', '<A-Down>', ":m'>+<CR>gv=gv")
map('v', '<A-Up>', ':m-2<CR>gv=gv')

vim.cmd([[ match ErrorMsg '\s\+$' ]])

local function last_non_empty(lines)
  for i = #lines, 1, -1 do
    if lines[i] ~= '' then
      return lines[i]
    end
  end
  return ''
end

local function fzf_term(cmd, on_choice)
  local output_file = vim.fn.tempname()
  local previous_win = vim.api.nvim_get_current_win()

  local max_height = math.max(1, vim.o.lines - 4)
  local height = math.min(max_height, math.max(10, math.floor(vim.o.lines * 0.4)))

  vim.cmd('botright ' .. height .. 'new')
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()

  vim.api.nvim_win_set_height(win, height)
  for name, value in pairs({
    statusline = ' ',
    number = false,
    signcolumn = 'no',
    colorcolumn = '',
    cursorline = false,
    cursorcolumn = false,
    list = false,
  }) do
    vim.wo[win][name] = value
  end
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buflisted = false
  vim.bo[buf].filetype = 'fzf'

  local job = vim.fn.termopen(cmd .. ' > ' .. vim.fn.shellescape(output_file), {
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          pcall(vim.api.nvim_win_close, win, true)
        end
        if vim.api.nvim_win_is_valid(previous_win) then
          vim.api.nvim_set_current_win(previous_win)
        end

        local lines = {}
        if vim.fn.filereadable(output_file) == 1 then
          lines = vim.fn.readfile(output_file)
        end
        vim.fn.delete(output_file)

        local choice = last_non_empty(lines)
        if exit_code == 0 and choice ~= '' then
          on_choice(choice)
        end
      end)
    end,
  })

  if job <= 0 then
    pcall(vim.api.nvim_win_close, win, true)
    vim.fn.delete(output_file)
    vim.notify('Failed to start fzf', vim.log.levels.ERROR)
    return
  end

  vim.cmd('startinsert')
end

local fzf_bind = [[--bind 'ctrl-left:backward-word,ctrl-right:forward-word']]

local function fzf(choice_cmd, vim_cmd)
  choice_cmd = choice_cmd ~= '' and choice_cmd or 'rg --files'
  fzf_term(choice_cmd .. ' | fzf ' .. fzf_bind, function(choice)
    vim.cmd(vim_cmd .. ' ' .. vim.fn.fnameescape(choice))
  end)
end

vim.api.nvim_create_user_command('Fzf', function(args)
  fzf(args.args, ':edit')
end, { nargs = '*', complete = 'shellcmd' })

map('n', '<leader>f', function()
  fzf('', ':edit')
end)

map('n', '<leader>e', function()
  local buffers = {}
  for _, buffer in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    table.insert(buffers, buffer.name)
  end

  local tmp = vim.fn.tempname()
  vim.fn.writefile(buffers, tmp)
  fzf('cat ' .. vim.fn.shellescape(tmp), ':buffer')
  vim.defer_fn(function()
    vim.fn.delete(tmp)
  end, 10000)
end)

local function rg(query)
  local rg_cmd = 'rg --line-number --column --no-heading --color=always'
  local fzf_cmd = 'fzf --ansi --disabled --print-query '
    .. fzf_bind
    .. ' --bind '
    .. vim.fn.shellescape('change:reload(' .. rg_cmd .. ' {q} || true)')

  local cmd = fzf_cmd .. ' | tail -1'
  if query ~= '' then
    local q = vim.fn.shellescape(query)
    cmd = '(' .. rg_cmd .. ' ' .. q .. ' || true) | ' .. fzf_cmd .. ' --query ' .. q .. ' | tail -1'
  end

  fzf_term(cmd, function(choice)
    local file, line, col = choice:match('^(.-):(%d+):(%d+):')
    if file and file ~= '' then
      vim.cmd('edit +' .. line .. ' ' .. vim.fn.fnameescape(file))
      vim.fn.cursor(tonumber(line), tonumber(col))
    end
  end)
end

vim.api.nvim_create_user_command('Rg', function(args)
  rg(args.args)
end, { nargs = '*' })

map('n', '<leader>g', function()
  rg('')
end)

opt.grepprg = 'rg --vimgrep'
opt.grepformat = '%f:%l:%c:%m'
local quickfix = augroup('quickfix', { clear = true })
autocmd('QuickFixCmdPost', {
  group = quickfix,
  pattern = '[^l]*',
  callback = function()
    vim.cmd('cwindow')
    vim.fn.setqflist({}, 'a')
    vim.cmd('redraw!')
  end,
})
autocmd('FileType', { group = quickfix, pattern = 'qf', command = 'resize 20' })

map('n', '<F2>', ':NERDTreeToggle<CR>', { silent = true })
map('n', '<F3>', ':NERDTreeFind<CR>', { silent = true })

autocmd('BufEnter', {
  group = augroup('nerdtree', { clear = true }),
  nested = true,
  callback = function()
    if vim.fn.winnr('$') == 1 and vim.b.NERDTree ~= nil then
      pcall(vim.cmd, 'confirm quit')
    end
  end,
})

autocmd('FileType', {
  group = augroup('commentstring', { clear = true }),
  pattern = { 'c', 'h', 'cpp', 'hpp' },
  callback = function()
    vim.bo.commentstring = '// %s'
  end,
})

autocmd('BufWritePost', {
  group = augroup('gitgutter_refresh', { clear = true }),
  command = 'silent! GitGutter',
})

vim.diagnostic.config({
  underline = false,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = 'x',
      [vim.diagnostic.severity.WARN] = 'w',
      [vim.diagnostic.severity.INFO] = '@',
      [vim.diagnostic.severity.HINT] = '*',
    },
  },
  float = {
    max_width = function()
      return math.min(88, math.floor(vim.o.columns * 0.6))
    end,
  },
})

local diagnostic_echoed = false
local diagnostic_echo_hl = {
  [vim.diagnostic.severity.ERROR] = 'ErrorMsg',
  [vim.diagnostic.severity.WARN] = 'WarningMsg',
  [vim.diagnostic.severity.INFO] = 'MoreMsg',
  [vim.diagnostic.severity.HINT] = 'Comment',
}

local function clear_diagnostic_echo()
  if diagnostic_echoed then
    vim.api.nvim_echo({ { '' } }, false, {})
    diagnostic_echoed = false
  end
end

local function echo_line_diagnostic()
  local diagnostics = vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })
  if #diagnostics == 0 then
    clear_diagnostic_echo()
    return
  end

  table.sort(diagnostics, function(a, b)
    return a.severity < b.severity
  end)

  local diagnostic = diagnostics[1]
  local source = diagnostic.source and diagnostic.source ~= '' and diagnostic.source .. ': ' or ''
  local message = (source .. diagnostic.message):gsub('\n', ' ')
  vim.api.nvim_echo({ { message, diagnostic_echo_hl[diagnostic.severity] or 'None' } }, false, {})
  diagnostic_echoed = true
end

local diagnostic_echo = augroup('diagnostic_echo', { clear = true })
autocmd({ 'CursorHold', 'CursorHoldI' }, { group = diagnostic_echo, callback = echo_line_diagnostic })
autocmd({ 'CursorMoved', 'CursorMovedI' }, { group = diagnostic_echo, callback = clear_diagnostic_echo })

local lsp_servers = { 'gopls', 'rust_analyzer', 'zls' }

vim.lsp.config.gopls = {
  cmd = { 'gopls', 'serve' },
  filetypes = { 'go' },
  root_markers = { 'go.work', 'go.mod', '.git' },
  settings = {
    gopls = {
      staticcheck = false,
    },
  },
}

vim.lsp.config.rust_analyzer = {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  root_markers = { 'Cargo.toml', '.git' },
  settings = {
    ['rust-analyzer'] = {
      cargo = { buildScripts = { enable = true } },
      procMacro = { enable = true },
    },
  },
}

vim.lsp.config.zls = {
  cmd = { 'zls' },
  filetypes = { 'zig' },
  root_markers = { 'build.zig', '.git' },
}

vim.lsp.enable(lsp_servers)

vim.api.nvim_create_user_command('LspStartServer', function()
  vim.lsp.enable(lsp_servers)
end, { nargs = '*', bang = true })

autocmd('LspAttach', {
  group = augroup('lsp', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    client.server_capabilities.semanticTokensProvider = nil

    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end
  end,
})

map('n', 'gd', vim.lsp.buf.definition, { silent = true })
map('n', 'gds', function()
  vim.cmd('split')
  vim.lsp.buf.definition()
end, { silent = true })
map('n', 'gtd', vim.lsp.buf.type_definition, { silent = true })
map('n', 'gi', vim.lsp.buf.implementation, { silent = true })
map('n', 'gr', vim.lsp.buf.rename, { silent = true })
map('n', 'gn', function()
  vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
end, { silent = true })
map('n', 'gp', function()
  vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
end, { silent = true })
map('n', 'gj', vim.lsp.buf.references, { silent = true })
map('n', 'gh', function()
  vim.lsp.buf.hover({
    border = {
      { '┌', 'LspHoverBorder' },
      { '─', 'LspHoverBorder' },
      { '┐', 'LspHoverBorder' },
      { '│', 'LspHoverBorder' },
      { '┘', 'LspHoverBorder' },
      { '─', 'LspHoverBorder' },
      { '└', 'LspHoverBorder' },
      { '│', 'LspHoverBorder' },
    },
    max_width = math.min(88, math.floor(vim.o.columns * 0.6)),
  })
end, { silent = true })
map('n', 'gm', function()
  vim.lsp.buf.code_action({
    apply = true,
    context = { only = { 'source.organizeImports' } },
  })
end, { silent = true })
map('i', '<leader>c', function()
  vim.lsp.completion.get()
end)

map('i', '<Tab>', function()
  if vim.fn.pumvisible() == 1 then
    return '<C-n>'
  end
  return '<Tab>'
end, { expr = true })

map('i', '<S-Tab>', function()
  if vim.fn.pumvisible() == 1 then
    return '<C-p>'
  end
  return '<S-Tab>'
end, { expr = true })

local function format(formatter)
  local view = vim.fn.winsaveview()
  local old = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local input = table.concat(old, '\n')
  if vim.bo.endofline then
    input = input .. '\n'
  end

  local formatted = vim.fn.systemlist(formatter, input)
  if vim.v.shell_error ~= 0 then
    vim.notify('Formatting failed: ' .. formatter, vim.log.levels.ERROR)
    return
  end

  if #formatted == 0 then
    formatted = { '' }
  end
  if vim.deep_equal(formatted, old) then
    return
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted)
  vim.fn.winrestview(view)
end

local autoformat = augroup('autoformat', { clear = true })
for pattern, formatter in pairs({
  ['*.go'] = 'gofmt',
  ['*.zig'] = 'zig fmt --stdin',
  ['*.rs'] = 'rustfmt --config max_width=120 --edition=2024',
  ['*.proto'] = 'clang-format -assume-filename=foobar.proto',
}) do
  autocmd('BufWritePre', {
    group = autoformat,
    pattern = pattern,
    callback = function()
      format(formatter)
    end,
  })
end

local function setlocal(settings)
  for name, value in pairs(settings) do
    vim.opt_local[name] = value
  end
end

local filetypes = augroup('filetypedetect', { clear = true })
for _, config in ipairs({
  { 'python', { expandtab = true, softtabstop = 4, textwidth = 80, colorcolumn = '80' } },
  { 'yaml', { expandtab = true, shiftwidth = 2, softtabstop = 2, tabstop = 2 } },
  { 'proto', { expandtab = true, softtabstop = 4 } },
  { { 'rst', 'markdown', 'text' }, { textwidth = 120, colorcolumn = '120', spell = true } },
  { { 'mail', 'gitcommit' }, { textwidth = 72, colorcolumn = '72', spell = true } },
  { 'sql', { omnifunc = '' } },
}) do
  local pattern, settings = config[1], config[2]
  autocmd('FileType', {
    group = filetypes,
    pattern = pattern,
    callback = function()
      setlocal(settings)
    end,
  })
end
