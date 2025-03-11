hi clear

if exists('syntax on')
    syntax reset
endif
let g:colors_name='off'

let s:bg              = { "gui": "#181818", "cterm": "234" }
let s:bg_light        = { "gui": "#545454", "cterm": "240" }
let s:bg_subtle       = { "gui": "#46484A", "cterm": "238" }
let s:bg_very_subtle  = { "gui": "#303030", "cterm": "236" }
let s:bg_sel          = { "gui": "#005F00", "cterm": "022" }
let s:fg              = { "gui": "#C6C6C6", "cterm": "251" }

let s:comment         = { "gui": "#4E4E4E", "cterm": "241" }
let s:string          = { "gui": "#79740E", "cterm": "100" }
let s:number          = { "gui": "#8787AF", "cterm": "103" }
let s:constant        = { "gui": "#8787AF", "cterm": "103" }
let s:cursor          = { "gui": "#323232", "cterm": "236" }
let s:keyword         = { "gui": "#9E9E9E", "cterm": "247" }
let s:title           = { "gui": "#5F8787", "cterm": "067" }

let s:red             = { "gui": "#B16286", "cterm": "132" }
let s:green           = { "gui": "#66800B", "cterm": "064" }
let s:yellow          = { "gui": "#87Af00", "cterm": "106" }
let s:blue            = { "gui": "#5F87AF", "cterm": "067" }
let s:purple          = { "gui": "#6855DE", "cterm": "062" }
let s:cyan            = { "gui": "#4FB8CC", "cterm": "038" }
let s:white           = { "gui": "#F2F0E5", "cterm": "255" }
let s:gray            = { "gui": "#767676", "cterm": "243" }
let s:light_gray      = { "gui": "#D3D3D3", "cterm": "252" }

function! s:h(group, style)
  execute "highlight" a:group
    \ "guifg="   (has_key(a:style, "fg")    ? a:style.fg.gui   : "NONE")
    \ "guibg="   (has_key(a:style, "bg")    ? a:style.bg.gui   : "NONE")
    \ "guisp="   (has_key(a:style, "sp")    ? a:style.sp.gui   : "NONE")
    \ "gui="     (has_key(a:style, "gui")   ? a:style.gui      : "NONE")
    \ "ctermfg=" (has_key(a:style, "fg")    ? a:style.fg.cterm : "NONE")
    \ "ctermbg=" (has_key(a:style, "bg")    ? a:style.bg.cterm : "NONE")
    \ "cterm="   (has_key(a:style, "cterm") ? a:style.cterm    : "NONE")
endfunction

call s:h("Normal",    {"bg": s:bg, "fg": s:fg})
call s:h("Cursor",    {"bg": s:cursor, "fg": s:fg})
call s:h("Comment",   {"fg": s:comment})
call s:h("Keyword",   {"fg": s:keyword})
call s:h("Constant",  {"fg": s:constant})
call s:h("String",    {"fg": s:string})
call s:h("Number",    {"fg": s:number})

hi! link Character        Constant
hi! link Boolean          Constant
hi! link Float            Number
hi! link Number           Number
hi! link String           String

hi! link Identifier       Normal
hi! link Function         Identifier

hi! link Conditonal       Normal
hi! link Repeat           Normal
hi! link Label            Normal
hi! link Operator         Normal
hi! link Statement        Keyword
hi! link Exception        Normal
hi! link Structure        Normal

hi! link PreProc          Normal
hi! link Include          PreProc
hi! link Define           PreProc
hi! link Macro            PreProc
hi! link PreCondit        PreProc

hi! link Type             Normal
hi! link StorageClass     Type
hi! link Typedef          Type

hi! link Special          Normal
hi! link SpecialChar      Special
hi! link Tag              Special
hi! link Delimiter        Special
hi! link SpecialComment   Special
hi! link Debug            Special

call s:h("Underlined",    {"fg": s:fg, "gui": "underline", "cterm": "underline"})
call s:h("Ignore",        {"fg": s:bg})
call s:h("Error",         {"fg": s:red})
call s:h("Todo",          {"fg": s:white })
call s:h("NonText",       {"fg": s:bg_subtle})
call s:h("SpecialKey",    {"fg": s:bg_subtle})
call s:h("Directory",     {"fg": s:title})
call s:h("ErrorMsg",      {"fg": s:red})
call s:h("IncSearch",     {"bg": s:yellow, "fg": s:bg})
call s:h("Search",        {"bg": s:yellow, "fg": s:bg})
call s:h("MoreMsg",       {"fg": s:fg, "cterm": "bold", "gui": "bold"})
hi! link ModeMsg MoreMsg
call s:h("LineNr",        {"fg": s:gray})
call s:h("CursorLineNr",  {"fg": s:fg, "bg": s:bg_very_subtle})
call s:h("Question",      {"fg": s:red})
call s:h("StatusLine",    {"bg": s:bg_very_subtle})
call s:h("StatusLineNC",  {"bg": s:bg_very_subtle, "fg": s:fg})
call s:h("VertSplit",     {"bg": s:bg_very_subtle, "fg": s:bg_very_subtle})
call s:h("Title",         {"fg": s:title})
call s:h("Visual",        {"bg": s:bg_sel})
call s:h("VisualNOS",     {"bg": s:bg_sel})
call s:h("WarningMsg",    {"fg": s:red})
call s:h("WildMenu",      {"fg": s:fg, "bg": s:bg_sel})
call s:h("Folded",        {"fg": s:gray})
call s:h("FoldColumn",    {"fg": s:bg_subtle})
call s:h("DiffAdd",       {"fg": s:green})
call s:h("DiffDelete",    {"fg": s:red})
call s:h("DiffChange",    {"fg": s:yellow})
call s:h("DiffText",      {"fg": s:green})
call s:h("SignColumn",    {"fg": s:green})

if has("gui_running")
  call s:h("SpellBad",    {"gui": "none", "sp": s:red})
  call s:h("SpellCap",    {"gui": "none"})
  call s:h("SpellRare",   {"gui": "none", "sp": s:red})
  call s:h("SpellLocal",  {"gui": "none", "sp": s:red})
else
  call s:h("SpellBad",    {"cterm": "none", "fg": s:red})
  call s:h("SpellCap",    {"cterm": "none"})
  call s:h("SpellRare",   {"cterm": "none", "fg": s:red})
  call s:h("SpellLocal",  {"cterm": "none", "fg": s:red})
endif

call s:h("Pmenu",         {"fg": s:fg, "bg": s:bg_subtle})
call s:h("PmenuSel",      {"fg": s:fg, "bg": s:bg_sel})
call s:h("PmenuSbar",     {"fg": s:fg, "bg": s:bg})
call s:h("PmenuThumb",    {"fg": s:fg, "bg": s:bg})
call s:h("TabLine",       {"fg": s:fg, "bg": s:bg_very_subtle})
call s:h("TabLineSel",    {"fg": s:fg, "bg": s:bg_sel, "gui": "bold", "cterm": "bold"})
call s:h("TabLineFill",   {"fg": s:fg, "bg": s:bg_very_subtle})
call s:h("CursorColumn",  {"bg": s:bg_very_subtle})
call s:h("CursorLine",    {"bg": s:bg_very_subtle})
call s:h("ColorColumn",   {"bg": s:bg_subtle})

call s:h("MatchParen",    {"bg": s:bg_sel})
call s:h("qfLineNr",      {"fg": s:gray})

call s:h("htmlH1",        {"bg": s:bg, "fg": s:fg})
call s:h("htmlH2",        {"bg": s:bg, "fg": s:fg})
call s:h("htmlH3",        {"bg": s:bg, "fg": s:fg})
call s:h("htmlH4",        {"bg": s:bg, "fg": s:fg})
call s:h("htmlH5",        {"bg": s:bg, "fg": s:fg})
call s:h("htmlH6",        {"bg": s:bg, "fg": s:fg})

hi SpellBad cterm=undercurl ctermbg=NONE guibg=NONE

hi SignColumn ctermbg=NONE guibg=NONE
hi Todo       ctermbg=NONE guibg=NONE cterm=NONE gui=NONE
hi Error      ctermbg=NONE guibg=NONE cterm=NONE gui=NONE
