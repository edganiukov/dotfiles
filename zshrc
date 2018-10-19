# exports

# General vars
export PATH=/usr/local/bin:$PATH
export GPG_TTY=$(tty)
export EDITOR=vim

export CDPATH=.:~/dev/go/src/github.com/edganiukov
export CLICOLOR=YES

# Go vars
export GOPATH=$HOME/go:$HOME/dev/go:$HOME/work/go
export PATH=$HOME/go/bin:$HOME/dev/go/bin:$PATH
export GO111MODULE=auto

# Rust vars
export PATH=$HOME/.cargo/bin:$PATH
export RUST_SRC_PATH=$HOME/.cargo/src/rust/src

# LLVM vars
export PATH=/usr/local/opt/llvm/bin:$PATH

# Set LS_COLORS
# [ -f ~/.dir_colors ] && eval `dircolors -b ~/.dir_colors`

# History settings
HISTFILE=~/.histfile
HISTSIZE=3000
SAVEHIST=3000

setopt append_history
setopt inc_append_history
setopt no_hist_beep
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_expire_dups_first
setopt hist_save_no_dups
setopt hist_find_no_dups
setopt hist_reduce_blanks
setopt share_history
setopt hist_verify

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
alias curl="curl -s"

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

##### custom tools
# pet
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

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# tm - create new tmux session, or switch to existing one. Works from within tmux too. (@bag-man)
# `tm` will allow you to select your tmux session via fzf.
# `tm irc` will attach to the irc session (if it exists), else it will create it.
tm() {
  [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
  if [ $1 ]; then
    tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1"); return
  fi
  session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) &&  tmux $change -t "$session" || echo "No sessions found."
}

# fs [FUZZY PATTERN] - Select selected tmux session
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
fs() {
  local session
  session=$(tmux list-sessions -F "#{session_name}" | \
    fzf --query="$1" --select-1 --exit-0) &&
  tmux switch-client -t "$session"
}

# fp - switch pane (@george-b)
fp() {
  local panes current_window current_pane target target_window target_pane
  panes=$(tmux list-panes -s -F '#I:#P - #{pane_current_path} #{pane_current_command}')
  current_pane=$(tmux display-message -p '#I:#P')
  current_window=$(tmux display-message -p '#I')

  target=$(echo "$panes" | grep -v "$current_pane" | fzf +m --reverse) || return

  target_window=$(echo $target | awk 'BEGIN{FS=":|-"} {print$1}')
  target_pane=$(echo $target | awk 'BEGIN{FS=":|-"} {print$2}' | cut -c 1)

  if [[ $current_window -eq $target_window ]]; then
    tmux select-pane -t ${target_window}.${target_pane}
  else
    tmux select-pane -t ${target_window}.${target_pane} &&
    tmux select-window -t $target_window
  fi
}

# custom
[ -f ~/.zshrc.custom ] && source ~/.zshrc.custom
