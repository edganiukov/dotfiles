### env vars

# General vars
export LANG=en_US.UTF-8
export PATH=/usr/local/bin:$PATH
export GPG_TTY=$(tty)
export EDITOR=nvim

export PATH="/usr/local/opt/qt/bin:$PATH"

export CDPATH=.:~/dev/go/src/github.com/edganiukov
export CLICOLOR=YES

# Go vars
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:/usr/local/opt/go/libexec/bin:$PATH
export GO111MODULE=auto

# Rust vars
[ -f $HOME/.cargo/env ] && source $HOME/.cargo/env

# LLVM vars
export PATH=/usr/local/opt/llvm/bin:$PATH
export LDFLAGS="-L/usr/local/opt/llvm/lib"
export CPPFLAGS="-I/usr/local/opt/llvm/include"

# java
export JAVA_HOME=$(/usr/libexec/java_home)

### settings
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000

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

### completion
autoload -Uz compinit
compinit

zstyle ':completion:*' completer _expand _complete _ignored
zstyle :compinstall filename '~/.zshrc'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

### binds
# delete
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
# disabled in favor of zsh-history-substring-search plugin
# bindkey "\e[A" history-search-backward
# bindkey "\e[B" history-search-forward

# Ctrl + Left/Right
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# Ctrl+k remove to eol
bindkey "\C-k" vi-kill-eol

### aliases
alias ls='ls -h'
alias df='df -h'
alias lsl='ls -hl'

alias mv='mv -i'
alias cp='cp -Ri'

alias tmux="tmux -u2"
alias wget="wget --continue --content-disposition"
alias grep="grep --colour"
alias curl="curl -s"
alias k="kubectl"

### prompt
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

### plugins
# https://github.com/zsh-users/zsh-history-substring-search
if [ -f ~/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh ]; then
    source ~/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh
    bindkey "\e[A" history-substring-search-up
    bindkey "\e[B" history-substring-search-down
    # bindkey '^[[A' history-substring-search-up
    # bindkey '^[[B' history-substring-search-down

    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=white,bold'
    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='fg=red,bold'
fi

# https://github.com/zsh-users/zsh-autosuggestions
if [ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# https://github.com/zsh-users/zsh-completions
if [ -d ~/.zsh/zsh-completions/src ]; then
    fpath=(~/.zsh/zsh-completions/src $fpath)
fi

### custom functions

# https://github.com/direnv/direnv
eval "$(direnv hook zsh)"

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

# Setup fzf
# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/usr/local/opt/fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/usr/local/opt/fzf/shell/key-bindings.zsh"

# tm - creates new tmux session, or switch to existing one.
tm() {
  [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
  if [ $1 ]; then
    tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1"); return
  fi
  session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) &&  tmux $change -t "$session" || echo "No sessions found."
}

# custom zsh config
[ -f ~/.zshrc.custom ] && source ~/.zshrc.custom
