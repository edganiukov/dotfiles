# exports
export GOPATH=$HOME/go:$HOME/dev/go:$HOME/work/go

export RUST_SRC_PATH=$HOME/.multirust/toolchains/stable-x86_64-apple-darwin/lib/rustlib/src/rust/src

export PATH=$PATH:$HOME/go/bin:$HOME/dev/go/bin:$HOME/.cargo/bin:/usr/local/bin

export GPG_TTY=$(tty)
export EDITOR=vim

export CDPATH=.:~/dev/go/src/github.com/edganiukov
export CLICOLOR=YES

# Set LS_COLORS
# [ -f ~/.dir_colors ] && eval `dircolors -b ~/.dir_colors`

# History settings
HISTFILE=~/.histfile
HISTSIZE=3000
SAVEHIST=3000
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt NO_HIST_BEEP
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_SAVE_NO_DUPS
setopt HIST_FIND_NO_DUPS
setopt SHARE_HISTORY
setopt HIST_VERIFY

setopt extended_glob
setopt noequals
setopt nobeep
setopt autocd
setopt nohup
setopt HASH_CMDS

# compinstall
autoload -Uz compinit
compinit

zstyle ':completion:*' completer _expand _complete _ignored
zstyle :compinstall filename '~/.zshrc'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# binds

# Delete
bindkey "^[[3~" delete-char

bindkey "^[e"   expand-cmd-path
bindkey " "     magic-space

# Home/End
bindkey "^[[7~" beginning-of-line
bindkey "^[[8~" end-of-line

# PgUp/PgDn
bindkey "^[[5"  up-line-or-history
bindkey "^[[6"  down-line-or-history

# Up/Down
bindkey "\e[A" history-search-backward
bindkey "\e[B" history-search-forward

# Ctrl + Left/Right
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# Ctrl+k remove to eol
bindkey "\C-k" vi-kill-eol

# aliases
alias ls='ls -h'
alias df='df -h'
alias lsl='ls -hl'

alias mv='mv -i'
alias cp='cp -Ri'
alias rmf='rm -f'
alias rmrf='rm -fR'

alias tmux="tmux -u2"
alias wget="wget --continue --content-disposition"
alias grep="grep --colour"

alias k="kubectl"

# prompt
autoload -Uz vcs_info
autoload -U promptinit
promptinit

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git*' formats "[%b]"
precmd() {
    vcs_info
}
setopt prompt_subst

PROMPT='%F{green}#>%f %F{yellow}%1~%f %F{magenta}${vcs_info_msg_0_}%f %# '
RPROMPT='[%F{yellow}%*%f]'

# custom tools
function prev() {
  PREV=$(fc -lrn | head -n 1)
  sh -c "pet new `printf %q "$PREV"`"
}

function pet-select() {
  BUFFER=$(pet search --query "$LBUFFER")
  CURSOR=$#BUFFER
  zle redisplay
}

zle -N pet-select
stty -ixon
bindkey '^s' pet-select

# calc
calc() { echo "$@" | bc -l -q -i }
alias calc='noglob calc'


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

[ -f ~/.zshrc.custom ] && source ~/.zshrc.custom
